#API server script

from flask import Flask, request, jsonify

app = Flask(__name__)

@app.route('/api/cmdb', methods=['POST'])

def receive_cmdb_data():
	data = request.get_json()
	print("Received data:", data)

# Optional: Save to file or database
	with open("cmdb_received.json", "a") as f:
		f.write(str(data) + "\n")
	return jsonify({"status": "success", "message": "Data received"}), 200
                            
if __name__ == '__main__':
	app.run(host='192.168.108.129', port=5000)
