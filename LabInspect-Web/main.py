from flask import Flask, render_template, request, redirect, url_for, send_file, jsonify, json, session
from pymongo import MongoClient
import qrcode
import io
import base64
from bson import ObjectId
from gridfs import GridFS
from datetime import timedelta

app = Flask(__name__)
app.secret_key = "labinspect"
app.permanent_session_lifetime = timedelta(minutes=5)

app.config['MONGO_URI'] = 'mongodb+srv://sonal:mongodbpassword@labinspect.v2zrssx.mongodb.net/?retryWrites=true&w=majority'

client = MongoClient(app.config['MONGO_URI'])
db = client.get_database('LabInspect')

# app.config['SESSION_TYPE'] = 'mongodb'
# app.config['SESSION_MONGODB'] = client['LabInspect']['scansession_data_collection']
# session(app)

login_collection = db.get_collection('Login')
commodity_data_collection = db.get_collection('commodity_data')
scansession_data_collection = db.get_collection('Scansession')
tempscanpost_collection = db.get_collection('Tempscanpost')
scanpost_collection = db.get_collection('Scanpost')
fs = GridFS(db)

@app.route('/')
def home_page():
    if 'pid' in session:
        return render_template('home.html',name=session['name'])
    else:
        return render_template('index.html')

@app.route('/signup', methods=['GET','POST'])
def signup():
    name = request.form.get('name')
    pid = request.form.get('userid')
    email = request.form.get('email')
    department = request.form.get('branch')
    designation = request.form.get('designation')
    password = request.form.get('password')
    confirm_password = request.form.get('confirm_password')

    if login_collection.find_one({'pid': pid}):
        return "Account already exists. Try logging in instead!"
    if password != confirm_password:
        return "Passwords do not match."
    elif password == confirm_password:
        login_collection.insert_one({'name': name, 'pid': pid, 'email': email, 'department': department, 'designation': designation, 'password': password})
    return redirect(url_for('home_page'))

@app.route('/login', methods=['GET','POST'])
def login():
    if 'pid' in session:
        return redirect(url_for('home_page'))
    if request.method == 'POST':
        pid = request.form.get('userid')
        password = request.form.get('password')
        user = login_collection.find_one({'pid': pid, 'password': password})
        if user:
            session['pid'] = pid
            session['name']= user['name']
            return redirect(url_for('home'))
        else:
            return "Login failed. Please check your credentials."
        
@app.route('/home', methods=['GET','POST'])
def home():
    if 'pid' in session:
        pid = session['pid']
        name = session['name']
        session['name'] = name
        session_data = scansession_data_collection.find({'pid':pid})
        return render_template('home.html',name=name, session_data=session_data)
    else:
        return redirect(url_for('home_page'))

@app.route('/admin')
def admin():
     return render_template('admin.html')

@app.route('/qrgen')
def qr():
     return render_template('qrgen.html')

@app.route("/generate_qr_code", methods=["GET","POST"])
def generate_qr_code():
    serial_number = request.form.get("serial_number")
    lab_number = request.form.get("lab_number")
    commodity_type = request.form.get("commodity_type")
    supplier = request.form.get("supplier")
    qr = qrcode.QRCode(
        version=1,
        error_correction=qrcode.constants.ERROR_CORRECT_L,
        box_size=5,
        border=1,
    )
    
    filename = f"qrcode_{lab_number}_{commodity_type}_{serial_number}.png"

    data_to_store = {
        "serial_number": serial_number,
        "lab_number": lab_number,
        "commodity_type": commodity_type,
        "supplier": supplier,
        "qr_code_image_filename": filename,
    }

    existing_data = commodity_data_collection.find_one(data_to_store)
    if existing_data:
        return render_template('replace.html', data=existing_data)
    else:
        qr.add_data(f"Serial: {serial_number}\nLab: {lab_number}\nType: {commodity_type}\nSupplier: {supplier}")
        qr.make(fit=True)
        img = qr.make_image(fill_color="black", back_color="white")
        img_byte_io = io.BytesIO()
        img.save(img_byte_io, format="PNG")
        img_bytes = img_byte_io.getvalue()
        fs.put(img_bytes, filename=filename)
        commodity_data_collection.insert_one(data_to_store)
        return redirect(url_for('download_qrcode', filename=filename))

@app.route("/download_qrcode/<filename>")
def download_qrcode(filename):
    image = fs.get_last_version(filename=filename)
    response = send_file(image, as_attachment=True, download_name=filename, mimetype="image/png")
    return response
 
@app.route("/fetch_qr", methods=["GET", "POST"])
def fetch_qr():
    if request.method == "POST":
        lab_number = request.form.get("lab_number")
        commodity_type = request.form.get("commodity_type")
        serial_number = request.form.get("serial_number")

        filename = f"qrcode_{lab_number}_{commodity_type}_{serial_number}.png"
        qr_code_data = fs.get_last_version(filename=filename)

        if qr_code_data:
            # filename = qr_code_data.name
            qr_code_bytes = qr_code_data.read()
            qr_code_base64 = base64.b64encode(qr_code_bytes).decode('utf-8')
            # return jsonify({"qr_code": qr_code_base64, "filename": filename})
            return jsonify({"qr_code": qr_code_base64})
    return render_template("qrgen.html")

@app.route("/replace", methods=['POST','GET'])
def replace():
    existing_data = request.form['existing_data']
    new_existing_data = existing_data[0:8]+existing_data[17:43]+existing_data[44:]
    new_existing_data = new_existing_data.replace("'",'"')
    # print(new_existing_data)
    json_existing_data = json.loads(new_existing_data)
    # Delete the existing document from the collection
    json_existing_data_id = ObjectId(json_existing_data['_id'])
    commodity_data_collection.delete_one({"_id": json_existing_data_id})
    # Delete the existing image from GridFS
    existing_image_filename = json_existing_data["qr_code_image_filename"]
    existing_image_id = fs.find_one({"filename": existing_image_filename})._id
    fs.delete(existing_image_id)
    # Generate a new QR code and save the data
    return render_template('qrgen.html')

@app.route('/getreport', methods=['POST'])
def getreport():
    if request.method == 'POST':
        try:
            existing_data = []
            data = request.data
            data = json.loads(data.decode('UTF-8'))
            pid = session['pid']
            labnumber = data['labnumber']
            date = data['date']
            find_document = {
                'pid': pid,
                'labnumber': labnumber,
                'date': date,
            }
            # print(find_document)
            existing_document = tempscanpost_collection.find_one(find_document)
            if existing_document:
                existing_data = existing_document.get('data',[])
                # print(existing_data)
                return jsonify({'documents': existing_data}), 200
            else:
                return jsonify({'documents': []}), 200
        except Exception as e:
            print(e)
            return jsonify({'error': 'Internal Server Error'}), 500

@app.route('/savedata', methods=['GET'])
def savedata():
    try:
        labnumber = request.args.get('labnumber')
        date = request.args.get('date')
        time = request.args.get('time')
        pid = session['pid']
        find_document = {
                'pid': pid,
                'labnumber': labnumber,
                'date': date,
            }
        find_document2 = {
                'pid': pid,
                'labnumber': labnumber,
                'date': date,
                'time': time
            }
        existing_document = tempscanpost_collection.find_one(find_document)
        if existing_document:
            scanpost_collection.insert_one(existing_document)
            tempscanpost_collection.find_one_and_delete(find_document)
            scansession_data_collection.find_one_and_delete(find_document2)
            return redirect(url_for('home'))
        return redirect(url_for('home'))
    except Exception as e:
        print(e)
    return redirect(url_for('home'))


@app.route('/logout')
def logout():
    session.clear()
    # session.pop('pid', None)  
    # session.pop('name', None)
    return redirect(url_for('home_page'))

if __name__ == "__main__":
    # app.run(debug=True)
    app.run(host='0.0.0.0',port=5000)

    # Pop out smth from a session using session.pop('field',None)
""" lines = input_string.split("\n")
key_value_pairs = [line.split(":") for line in lines if line]

# Create a dictionary from the key-value pairs
data_dict = {key.strip(): value.strip() for key, value in key_value_pairs}

# Convert the dictionary to a JSON string
json_data = json.dumps(data_dict, indent=4)

print(json_data) """