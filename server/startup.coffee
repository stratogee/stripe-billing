Meteor.startup ->

	# Publish user with billing object
	Meteor.publish 'currentUser', ->
	  Meteor.users.find _id: @userId, 
	    fields: billing: 1