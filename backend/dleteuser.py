from database import SessionLocal, User, Message, Contact, ContactRequest, GroupMember
db = SessionLocal()

username = input('Enter username to delete: ')
user = db.query(User).filter(User.username == username).first()

if not user:
    print(f'❌ User {username} not found!')
else:
    print(f'⚠️  Are you sure you want to delete {username} (ID: {user.id})?')
    confirm = input('Type YES to confirm: ')
    
    if confirm == 'YES':
        user_id = user.id
        # 1. Delete messages
        db.query(Message).filter((Message.sender_id == user_id) | (Message.receiver_id == user_id)).delete(synchronize_session=False)
        # 2. Delete contacts
        db.query(Contact).filter((Contact.user_id == user_id) | (Contact.contact_id == user_id)).delete(synchronize_session=False)
        # 3. Delete contact requests
        db.query(ContactRequest).filter((ContactRequest.from_user_id == user_id) | (ContactRequest.to_user_id == user_id)).delete(synchronize_session=False)
        # 4. Remove from groups
        db.query(GroupMember).filter(GroupMember.user_id == user_id).delete(synchronize_session=False)
        # 5. Delete user
        db.delete(user)
        db.commit()
        print(f'✅ User {username} and all associated data deleted!')
    else:
        print('❌ Cancelled.')
db.close()
