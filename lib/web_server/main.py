import os

from flask import Flask, jsonify, request, send_file

app = Flask(__name__)

# Example data that simulates requests from a server
requests_data = [
    {"name": "Emma Johnson", "email": "emma@example.com", "message": "Looking forward to guiding."},
    {"name": "Liam Smith", "email": "liam@example.com", "message": "Excited to join the team."},
    {"name": "Olivia Williams", "email": "olivia@example.com", "message": "Passionate about tours."},
    {"name": "Noah Brown", "email": "noah@example.com", "message": "Eager to get started."},
    {"name": "Ava Davis", "email": "ava@example.com", "message": "Love sharing knowledge."},
    {"name": "Elijah Miller", "email": "elijah@example.com", "message": "Can’t wait to guide tours."},
    {"name": "Sophia Wilson", "email": "sophia@example.com", "message": "Tour guiding is my passion."},
    {"name": "James Taylor", "email": "james@example.com", "message": "Ready to start guiding."},
    {"name": "Isabella Anderson", "email": "isabella@example.com", "message": "Happy to be a part of this."},
    {"name": "Benjamin Thomas", "email": "benjamin@example.com", "message": "Let’s start the tours."},
    {"name": "Emma Johnson", "email": "emma@example.com", "message": "Looking forward to guiding."},
    {"name": "Liam Smith", "email": "liam@example.com", "message": "Excited to join the team."},
    {"name": "Olivia Williams", "email": "olivia@example.com", "message": "Passionate about tours."},
    {"name": "Noah Brown", "email": "noah@example.com", "message": "Eager to get started."},
    {"name": "Ava Davis", "email": "ava@example.com", "message": "Love sharing knowledge."},
    {"name": "Elijah Miller", "email": "elijah@example.com", "message": "Can’t wait to guide tours."},
    {"name": "Sophia Wilson", "email": "sophia@example.com", "message": "Tour guiding is my passion."},
    {"name": "James Taylor", "email": "james@example.com", "message": "Ready to start guiding."},
    {"name": "Isabella Anderson", "email": "isabella@example.com", "message": "Happy to be a part of this."},
    {"name": "Benjamin Thomas", "email": "benjamin@example.com", "message": "Let’s start the tours."}
]

@app.route('/submit-user-data', methods=['POST'])
def submit_user_data():
    # Extract user data from the request body
    data = request.json
    uid = data.get('uid')
    username = data.get('username')
    email = data.get('email')
    auth_state = data.get('authState')
    registration_data = data.get('registrationData')

    description = registration_data.get('description')
    uploaded_url = registration_data.get('uploadedUrl')

    # Process the user data (e.g., save to a database)
    # Replace this with your actual data processing logic
    print('Received user data:')
    print('UID:', uid)
    print('Username:', username)
    print('Email:', email)
    print('Auth State:', auth_state)
    print('Description:', description)
    print('Uploaded URL:', uploaded_url)

     # Create new request data
    new_request = {
        "name": username,
        "email": email,
        "message": description
    }

    # Add the new request to the list of requests
    requests_data.append(new_request)
    
    # Respond with a success message
    return jsonify({'message': 'User data received successfully'})

@app.route('/requests')
def get_requests():
    page = int(request.args.get('page', 1))
    pageSize = int(request.args.get('pageSize', 10))
    search_query = request.args.get('search', '').lower()

    # Filter requests based on search query
    filtered_requests = [req for req in requests_data if search_query in req['name'].lower()]

    # Paginate the filtered requests
    start_index = (page - 1) * pageSize
    end_index = min(start_index + pageSize, len(filtered_requests))
    paginated_data = filtered_requests[start_index:end_index]

    return jsonify({
        "requests": paginated_data,
        "totalItems": len(filtered_requests)
    })

@app.route('/')
def serve_index():
    return send_file('index.html')

@app.route('/static/<path:path>')
def send_static(path):
    return send_file(os.path.join('static', path))

if __name__ == '__main__':
    app.run(debug=True)
