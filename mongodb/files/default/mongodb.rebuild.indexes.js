db = db.getSiblingDB('core');

db.users.dropIndexes();
db.creators.dropIndexes();
db.comments.dropIndexes();
db.conversations.dropIndexes();
db.permissions.dropIndexes();
db.follows.dropIndexes();
db.groups.dropIndexes();



db.users.ensureIndex({alias:1},{unique:true});
db.users.ensureIndex({uid:1},{unique:true});
db.creators.ensureIndex({uid:1},{unique:true});
db.conversations.ensureIndex({uid:1},{unique:true});
db.conversations.ensureIndex({creator:1});
db.conversations.ensureIndex({group:1});
db.comments.ensureIndex({uid:1},{unique:true});
db.comments.ensureIndex({conversation:1,user:1});
db.permissions.ensureIndex({uid:1},{unique:true});
db.permissions.ensureIndex({type:1,value:1},{unique:true});
db.follows.ensureIndex({uid:1},{unique:true});
db.follows.ensureIndex({creator:1,user:1});
db.groups.ensureIndex({uid:1},{unique:true});


db = db.getSiblingDB('votes');

db.votes.dropIndexes();
db.votes.ensureIndex({uid:1},{unique:true});
db.votes.ensureIndex({user:1,value:1});

db = db.getSiblingDB('payments');

db.balances.dropIndexes();
db.balances.ensureIndex({user:1});
db.wallets.dropIndexes();
db.subscriptions.dropIndexes();
db.pledges.dropIndexes();
db.charges.dropIndexes();

db.balances.ensureIndex({uid:1},{unique:true});
db.wallets.ensureIndex({uid:1},{unique:true});
db.subscriptions.ensureIndex({uid:1},{unique:true});
db.pledges.ensureIndex({uid:1},{unique:true});
db.charges.ensureIndex({uid:1},{unique:true});


db = db.getSiblingDB('leaderboard');

db.ranks.dropIndexes();
db.scores.dropIndexes();
db.totals.dropIndexes();

db.ranks.ensureIndex({uid:1},{unique:true});
db.ranks.ensureIndex({type:1,updatedAt:1,list:1});
db.scores.ensureIndex({uid:1},{unique:true});
db.scores.ensureIndex({type:1,updatedAt:1,object:1});
db.totals.ensureIndex({uid:1},{unique:true});
db.totals.ensureIndex({updatedAt:1,object:1,sum:1});

db = db.getSiblingDB('log');

db.activity.dropIndexes();
db.payments.dropIndexes();

db.activity.ensureIndex({uid:1},{unique:true});
db.activity.ensureIndex({object:1,service:1,action:1,createdAt:1});

db.payments.ensureIndex({uid:1},{unique:true});
db.payments.ensureIndex({user:1,action:1,createdAt:1});
