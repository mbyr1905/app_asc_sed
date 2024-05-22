from flask import Flask, request, jsonify
import werkzeug
import numpy as np
from tensorflow.keras.models import load_model
from sklearn.preprocessing import LabelEncoder
import os
import librosa 
import pickle
import wave
from pathlib import Path
import matplotlib.pyplot as plt
from tensorflow.keras.preprocessing.image import load_img, img_to_array

app = Flask(__name__)

@app.route('/upload_audio', methods=['POST'])
def upload_audio():
    if request.method == 'POST':
        audio_file = request.files['audio']
        filename = "test.wav"
        audio_file.save("D:/flutter_projects/audio_capture_saving_to_server/server/uploaded_audio/" + filename)
        return jsonify({
            "message": "Audio uploaded successfully"
        })
        
def calculate_zcr_and_save(audio_file, output_dir):
    try:
        # Read the WAV file
        wav = wave.open(audio_file, 'r')
        frames = wav.readframes(-1)
        sound_info = np.frombuffer(frames, dtype=np.int16)
        frame_rate = wav.getframerate()
        wav.close()

        # Calculate ZCR
        zcr = np.mean(np.abs(np.diff(np.sign(sound_info))) / 2.0)

        # Extract the file name without extension
        filename = os.path.splitext(os.path.basename(audio_file))[0]

        # Save the ZCR value to a text file in the output directory
        zcr_file_path = os.path.join(output_dir, 'test_zcr.txt')
        with open(zcr_file_path, 'w') as f:
            f.write(f'ZCR: {zcr}')
    except Exception as e:
        print(f"An error occurred for {audio_file}: {e}")
        

# Function to calculate MFCCs and save results
def calculate_mfcc_and_save(audio_file, output_dir):
    try:
        # Extract the file name without extension
        filename = os.path.splitext(os.path.basename(audio_file))[0]

        # Calculate MFCCs
        audio, sample_rate = librosa.load(audio_file, sr=None)  # Load the audio file
        mfccs = librosa.feature.mfcc(y=audio, sr=sample_rate, n_mfcc=13)  # You can adjust the number of MFCC coefficients
        # print(mfccs.shape)
        # Save the MFCCs to a binary file in the output directory (overwrite if it already exists)
        np.save(os.path.join(output_dir, 'test_mfcc.npy'), mfccs)
    except Exception as e:
        print(f"An error occurred for {audio_file}: {e}")
        

# Function to generate mel spectrogram and save as an image
def generate_mel_spectrogram_and_save(file_path, output_dir):
    try:
        file_stem = Path(file_path).stem
        file_dist_path = os.path.join(output_dir, 'test_image.png')

        # Load the audio file
        y, sr = librosa.load(file_path, sr=None)

        # Calculate the mel spectrogram
        mel_spectrogram = librosa.feature.melspectrogram(y=y, sr=sr)

        # Convert to decibels
        log_mel_spec = librosa.power_to_db(mel_spectrogram, ref=np.max)
        
        # Plot and save the spectrogram image (overwrite if it already exists)
        plt.figure(figsize=(8, 6))
        librosa.display.specshow(log_mel_spec, sr=sr, x_axis='time', y_axis='mel')
        plt.colorbar(format='%+2.0f dB')
        plt.title(f"Spectrogram for {os.path.basename(file_path)}")
        plt.savefig(file_dist_path)
        plt.close()
    except Exception as e:
        print(f"An error occurred for {file_path}: {e}")

@app.route('/predict_asc', methods=['GET'])
def predict_asc():
    prediction_directory = r"D:\flutter_projects\audio_capture_saving_to_server\server\uploaded_audio"
    model = pickle.load(open(r"D:\flutter_projects\flask_model_running\mbyr\flask\model_asc.pkl", 'rb'))
    label_encoder_classes = np.load(r"D:\prediction\saved_models_tf\label_encoder_classes_asc.npy")
    d={}
    # Iterate through all files in the directory
    OUTPUT_DIR = r"D:\flutter_projects\audio_capture_saving_to_server\server\saved_params"
    OUTPUT_DIR_ZCR = r"D:\flutter_projects\audio_capture_saving_to_server\server\saved_params\zcr"
    OUTPUT_DIR_MFCC= r"D:\flutter_projects\audio_capture_saving_to_server\server\saved_params\mfcc"
    OUTPUT_DIR_LOG_MEL=r"D:\flutter_projects\audio_capture_saving_to_server\server\saved_params\audio-images"

    os.makedirs(OUTPUT_DIR, exist_ok=True)
    os.makedirs(OUTPUT_DIR_ZCR, exist_ok=True)
    os.makedirs(OUTPUT_DIR_MFCC, exist_ok=True)
    os.makedirs(OUTPUT_DIR_LOG_MEL, exist_ok=True)
    for filename in os.listdir(prediction_directory):
        if filename.endswith(".wav"):
            file_path = os.path.join(prediction_directory, filename)

            # Assuming you have these functions defined
            calculate_zcr_and_save(file_path, OUTPUT_DIR_ZCR)
            calculate_mfcc_and_save(file_path, OUTPUT_DIR_MFCC)
            generate_mel_spectrogram_and_save(file_path, OUTPUT_DIR_LOG_MEL)

            # Load the processed data
            mfcc_data = np.load(r'D:\flutter_projects\audio_capture_saving_to_server\server\saved_params\mfcc\test_mfcc.npy')
            zcr_file_path = r'D:\flutter_projects\audio_capture_saving_to_server\server\saved_params\zcr\test_zcr.txt'

            # Load the spectrogram image and resize it to (64, 64)
            spectrogram_image_path = r"D:\flutter_projects\audio_capture_saving_to_server\server\saved_params\audio-images\test_image.png"
            spectrogram_image = load_img(spectrogram_image_path, target_size=(64, 64))
            spectrogram_data = img_to_array(spectrogram_image)
            spectrogram_data = np.expand_dims(spectrogram_data, axis=0)  # Add batch dimension
            spectrogram_data = spectrogram_data / 255.0  # Normalize pixel values
            
            # Ensure that both data arrays have the same number of samples
            num_frames = 13  # Change this to match your model input size
            num_mfcc_coefficients = 862  # Change this to match your model input size
            mfcc_data = mfcc_data[:num_frames, :num_mfcc_coefficients]
            mfcc_data = mfcc_data.T
            mfcc_data = np.expand_dims(mfcc_data, axis=0)
            
            # Normalize the MFCC data (adjust based on your training data)
            # Use the same normalization parameters as in the training phase
            mfcc_data = (mfcc_data - mfcc_data.mean()) / mfcc_data.std()
            desired_mfcc_shape = (1, 862, 13)
            if mfcc_data.shape[1] < desired_mfcc_shape[1]:
                padding_width = desired_mfcc_shape[1] - mfcc_data.shape[1]
                mfcc_data = np.pad(mfcc_data, ((0, 0), (0, padding_width), (0, 0)), mode='constant')
            # Normalize ZCR value (if needed)
            zcr_value = 0.0
            with open(zcr_file_path, 'r') as file:
                # Read the first line and extract the numeric value
                line = file.readline()
                zcr_value = float(line.split(':')[1].strip())
            zcr_value = np.array([zcr_value])
            zcr_value = np.expand_dims(zcr_value, axis=0)
            
            # print(mfcc_data.shape)
            # Predict the class using the loaded model
            predictions = model.predict([spectrogram_data, mfcc_data, zcr_value])
            predicted_label = np.argmax(predictions, axis=1)

            # Assuming label_encoder_classes is a dictionary mapping class indices to class labels
            predicted_class_label = label_encoder_classes[predicted_label[0]]
            #print("predicted_label:", predicted_label)  # Add this line for debugging

            #print("predicted_class_label:", predicted_class_label)
            class_names = [
                'class_airport', 'class_bus', 'class_metro', 'class_metro_station', 'class_park',
                'class_public_square', 'class_shopping_mall', 'class_street_pedestrian', 
                'class_street_traffic', 'class_tram'
            ]

            
            d[filename] = str(class_names[predicted_class_label])
    return jsonify(d)

@app.route('/predict_sed', methods=['GET'])
def predict_sed():
    prediction_directory = r"D:\flutter_projects\audio_capture_saving_to_server\server\uploaded_audio"
    model = pickle.load(open(r"D:\flutter_projects\flask_model_running\mbyr\flask\model_sed.pkl", 'rb'))
    labelencoder_classes_1 = np.load(r"D:\flutter_projects\audio_capture_saving_to_server\server\models\label_encoder_classes.npy")
    d={}
    for filename in os.listdir(prediction_directory):
        if filename.endswith(".wav"):
            file_path = os.path.join(prediction_directory, filename)

            # Load audio file
            audio, sample_rate = librosa.load(file_path, res_type='kaiser_fast') 
            mfccs_features = librosa.feature.mfcc(y=audio, sr=sample_rate, n_mfcc=40)
            mfccs_scaled_features = np.mean(mfccs_features.T, axis=0)

            # Reshape for prediction
            mfccs_scaled_features = mfccs_scaled_features.reshape(1, -1)

            # Make predictions using the loaded model
            predictions = model.predict(mfccs_scaled_features)

            # Get the index of the maximum value in predictions for each sample
            predicted_label = np.argmax(predictions, axis=1)
            print(predicted_label)
            
            # Convert the predicted label back to the original class using the label encoder classes
            prediction_class = labelencoder_classes_1[predicted_label[0]]

            d['test'] = str(prediction_class)
    return jsonify(d)

@app.route('/test', methods=['GET'])
def test():
    d={}
    d['test1']="hello"
    d['test2']="this is  the testing route for the running server"
    return jsonify(d)

if __name__ == '__main__':
    app.run()