from flask import Flask, render_template
import socket

app = Flask(__name__)

@app.route('/')

def homepage():
    hostname = socket.gethostname()
    return render_template('index.html', hostname=hostname)

@app.route('/health')
def health_check():
    return "OK", 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
