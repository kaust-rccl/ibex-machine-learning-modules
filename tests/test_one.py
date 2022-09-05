import tensorflow as tf
import numpy as np
# check if cuda is available
print("Is CUDA available: ", tf.test.is_gpu_available())
# check if cuda is enabled
print("Is CUDA enabled: ", tf.test.is_built_with_cuda())
# check tensorflow version
print("Tensorflow version: ", tf.__version__)
# check tensror operation on GPU
with tf.device('/gpu:0'):
    a = tf.constant([1, 2, 3, 4, 5, 6, 7], shape=[7, 1], name='a')
    b = tf.constant([1, 2, 3, 4, 5, 6, 7], shape=[1, 7], name='b')
    c = tf.matmul(a, b)
    # if this fails then you have a problem with your GPU
    print("Tensorflow operation on GPU: ", c)

# create a session to run the graph 
with tf.Session(config=tf.ConfigProto(log_device_placement=True)) as sess:
    print (sess.run(c))
