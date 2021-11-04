import flask
import pickle
import pandas as pd
import gensim
import nltk
#nltk.download('punkt')
#import gcsfs
import sys
sys.path.append("..")
from src.models import tf_idf_model

#fs = gcsfs.GCSFileSystem(project='w210-jcgy-254100')
#with fs.open('w210-jcgy-bucket/w210-data-output-new-q-and-a-files-with-separate-cleaned-answer-bodies/new_qs.csv', 'rb') as f:
#	m = tfModel(f)

m = tf_idf_model.tfModel('/mnt/disks/w210-jcgy-bucket/w210-data-output-new-q-and-a-files-with-separate-cleaned-answer-bodies/new_qs.csv')

# Initialise the Flask app
app = flask.Flask(__name__, template_folder='templates')

# Set up the main route
@app.route('/', methods=['GET', 'POST'])
def main():
    if flask.request.method == 'GET':
        # Just render the initial form, to get input
        return(flask.render_template('main.html'))

    if flask.request.method == 'POST':
        # Extract the input
        userquery = flask.request.form['userquery']
        options = flask.request.form['options']

        # Make DataFrame for model
        input_variables = userquery

        # Get the model's prediction
        #prediction = model.predict(input_variables)[0]

        if options == 'option 1':
            similar_que, similar_ans, similar_img, similar_code = m.get_similar_documents(input_variables, num_results=3)

        # Render the form again, but add in the prediction and remind user
        # of the values they input before
        return flask.render_template('result.html',
                                     original_input=userquery,
                                     que=similar_que,
                                     ans=similar_ans,
				     img=similar_img,
				     code=similar_code,
                                     )

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=3000)
