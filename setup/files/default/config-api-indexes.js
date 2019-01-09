db = db.getSiblingDB('oauth');
db.grants.createIndex({date:1},{expireAfterSeconds:86400});
db.access_token.createIndex({expiration:1},{expireAfterSeconds:0});


print("access_token",db.access_token.count());
print("grants",db.grants.count());



db = db.getSiblingDB('collegemarching');
db.sessions.createIndex({date:1},{expireAfterSeconds:86400});




print("sessions",db.sessions.count());
