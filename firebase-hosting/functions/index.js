const functions = require('firebase-functions');

const admin = require('firebase-admin');
admin.initializeApp();

const db = admin.firestore();
const serverTimestamp = admin.firestore.FieldValue.serverTimestamp();
const arrayUnion = admin.firestore.FieldValue.arrayUnion;

const now = () => admin.firestore.Timestamp.now().toMillis();

exports.onUserUpdate = functions.firestore
    .document('users/{userId}/config/userData')
    .onWrite(async (change, context) => {

        const data = change.after.data();
        const user = context.params.userId;

        if (change.before.data() == null) {
            const timestamp = now();
            await db.doc(`users/${user}/config/appData`).set({
                lastStatusFetch: timestamp,
                lastMessageFetch: timestamp,
            }, { merge: true });
            console.log(`user ${user}: creation complete`);
        }

        await Promise.all([
            db.doc(`users/${user}`).set(data, { merge: true }),
            db.doc(`users/${user}/data/${user}`)
                .set({ ...data, lastUpdate: serverTimestamp, composition: [user] }, { merge: true })
        ]);

        return console.log(`user ${user}: update complete`);
    });

exports.onNewMessage = functions.firestore
    .document('chatRooms/{roomId}/messages/{messageId}')
    .onWrite(async (change, context) => {

        const message = change.after.data();
        const room = context.params.roomId;

        if (message.type == null) {
            return console.log('no message');
        }

        if (message.type == 'friend-request' && message.action == 'request') {
            const sender = context.params.messageId.replace(`${room}_`, '');
            const receiver = message.sentTo.join('').replace(sender, '');

            const rConfig = {};
            const sConfig = {};
            rConfig[`${sender}`] = { mode: 'received-request' };
            sConfig[`${receiver}`] = { mode: 'sent-request' };

            const batch = db.batch();

            batch.set(db.doc(`users/${receiver}/config/friendsConfig`), rConfig, { merge: true })
                .set(db.doc(`users/${sender}/config/friendsConfig`), sConfig, { merge: true });

            await batch.commit();

            return console.log(`new friend request ${room}`);
        }

        if (message.type == 'friend-request' && message.action == 'accept') {
            const receiver = context.params.messageId.replace(`${room}_`, '');
            const sender = message.sentTo.join('').replace(receiver, '');
            const request = await db.doc(`chatRooms/${room}/messages/${room}_${sender}`).get();

            if (request.exists && request.data().type == 'friend-request' &&
                request.data().action == 'request') {
                const rConfig = {};
                const sConfig = {};
                rConfig[`${sender}`] = { mode: 'friends' };
                sConfig[`${receiver}`] = { mode: 'friends' };

                const batch = db.batch();

                batch.set(db.doc(`chatRooms/${room}/participants/${sender}`), { member: true }, { merge: true })
                    .set(db.doc(`chatRooms/${room}/participants/${receiver}`), { member: true }, { merge: true })
                    .set(db.doc(`users/${receiver}/config/friendsConfig`), rConfig, { merge: true })
                    .set(db.doc(`users/${sender}/config/friendsConfig`), sConfig, { merge: true })
                    .set(db.doc(`users/${receiver}/data/${receiver}`), { friends: arrayUnion(sender), lastUpdate: serverTimestamp }, { merge: true })
                    .set(db.doc(`users/${sender}/data/${sender}`), { friends: arrayUnion(receiver), lastUpdate: serverTimestamp }, { merge: true });

                await batch.commit();

                await db.doc(`chatRooms/${room}/messages/${room}_welcome`).set({
                    type: "text",
                    sentTo: [sender, receiver],
                    userId: "administrator",
                    username: "admin",
                    roomId: room,
                    timestamp: serverTimestamp,
                    lastUpdate: serverTimestamp,
                    text: "Welcome! You can now send messages in this room, happy chatting",
                    state: "sent"
                });

                return console.log(`new friend contract ${room}`);
            } else {
                return console.log('request does not exist');
            }
        }
        return console.log(`new message in ${room}`);
    });
