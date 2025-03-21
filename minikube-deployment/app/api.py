from flask import Flask
from flask import jsonify
from flask import request
#from flask_sqlalchemy import SQLAlchemy


app_name = 'comments'
app = Flask(app_name)
#app.config['SQLALCHEMY_DATABASE_URI'] = 'postgresql://user:senha@password:5432/comments'
#app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
#db = SQLAlchemy(app)


#class Comment(db.Model):
#    id = db.Column(db.Integer, primary_key=True)
#    comment = db.Column(db.String(500), nullable=False)
#    email = db.Column(db.String(100), nullable=False)

#    def __repr__(self):
#        return f'<Comment {self.id} - {self.author}>'

#with app.app_context():
#    db.create_all()

comments = {}

@app.route('/api/comment/new', methods=['POST'])
def api_comment_new():
    request_data = request.get_json()

    email = request_data['email']
    comment = request_data['comment']
    content_id = '{}'.format(request_data['content_id'])

    #new_comment = Comment(id=content_id, comment=comment, email=email)
    #db.session.add(new_comment)
    #db.session.commit()

    new_comment = {
            'email': email,
            'comment': comment,
            }

    if content_id in comments:
        comments[content_id].append(new_comment)
    else:
        comments[content_id] = [new_comment]

    message = 'comment created and associated with content_id {}'.format(content_id)
    response = {
            'status': 'SUCCESS',
            'message': message,
            }
    return jsonify(response), 200


@app.route('/api/comment/list/<content_id>')
def api_comment_list(content_id):
    #comment = Comment.query.get_or_404(content_id)
    content_id = '{}'.format(content_id)

    if content_id in comments:
        return jsonify(comments[content_id]), 200
    else:
        message = 'content_id {} not found'.format(content_id)
        response = {
                'status': 'NOT-FOUND',
                'message': message,
                }
        return jsonify(response), 404

@app.route('/')
def api_healthy_check():
    message = 'the app is healthy'
    response = {
                'status': 'HEALTHY',
                'message': message,
                }
    return jsonify(response), 200

if __name__ == '__main__':
    app.run('0.0.0.0', 8000, debug=True)