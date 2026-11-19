import os
os.environ["KERAS_BACKEND"] = "torch" #must come before "import keras"
import keras
from keras import layers
import numpy as np
import matplotlib.pyplot as plt
import json

d = keras.datasets.mnist.load_data()
print(type(d)) #a tuple of two tuples, (train, test)
print(len(d))
print(type(d[0])) #train is itself a tuple, (x, y)
print(len(d[0]))
print(type(d[0][0])) #a numpy array
print(d[0][0].shape) #60000 images, each 28 by 28 with a single channel (so grayscale)

## get x and y train and test
(x_train, y_train), (x_test, y_test) = d

## look at an image
# print(x_train[0])
plt.imshow(x_train[0], cmap="gray"); plt.show()
print(y_train[0]) #so this is a 5

# label vals (y val)
print(np.unique(y_train))

# reshape - get vector 1 x 28^2, not 28x28
x_train = x_train.reshape(x_train.shape[0], 28**2)
print(x_train.shape)
x_test = x_test.reshape(x_test.shape[0], 28**2)
print(x_test.shape)

# rescale 
print(x_train.min(), x_train.max())
print(x_test.min(), x_test.max()) #So these are integers 0 to 255, pretty
#standard for images
x_train = x_train.astype("float32") / 255
x_test = x_test.astype("float32") / 255

### get to sequential model nn

model1 = keras.Sequential([
    keras.Input(shape=(784,)),
    layers.Dense(units=256, activation="relu"),
    layers.Dropout(rate=0.4),
    layers.Dense(units=128, activation="relu"),
    layers.Dropout(rate=0.3),
    layers.Dense(units=10, activation="softmax")
])

# get summary to check how we set that up
model1.summary()

# compile model 
model1.compile(
  loss="sparse_categorical_crossentropy",
  optimizer=keras.optimizers.RMSprop(),
  metrics=["accuracy"]
)

# fit the model 1
history1 = model1.fit(
  x_train, y_train,
  epochs=30, batch_size=128,
  validation_split=0.2)

# make a function for a plot to check how it was performing
def plot_history(h):
  ep = range(1, len(h.history["loss"]) + 1)
  fig, ax = plt.subplots(2, 1, sharex=True)
  ax[0].plot(ep, h.history["loss"], "o-", label="training")
  ax[0].plot(ep, h.history["val_loss"], "o-", label="validation")
  ax[0].set_ylabel("loss"); ax[0].legend()
  ax[1].plot(ep, h.history["accuracy"], "o-", label="training")
  ax[1].plot(ep, h.history["val_accuracy"], "o-", label="validation")
  ax[1].set_ylabel("accuracy"); ax[1].set_xlabel("epoch")
  plt.show()

#shows the history - very similar to what came out as it trained
plot_history(history1)

#In R, typing history1 shows the final values. Same here.
def history_summary(h):
  print("Final epoch (" + str(len(h.history["loss"])) + "):")
  for k, v in h.history.items():
    print("  " + k + ": " + str(round(v[-1], 4)))

#Shows final values. Pretty good for a first try!
history_summary(history1)



