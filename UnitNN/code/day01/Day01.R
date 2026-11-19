# day 1 of neural network

library(keras3)
use_backend("torch")

# the simple dataset - mnist data 
d <- dataset_mnist()
# check the dim of train and test sets 
class(d)
names(d)
class(d$train)
names(d$train)
class(d$train$x)
dim(d$train$x) #60000 images, each 28 by 28 with a single channel (so grayscale)
dim(d$test$x) #10000 test images
dim(d$train$y) #60000 labels, each a single integer 0 to 9
head(d$train$y) #this is what digit each image shows

# get x and y of train and test sets 
x_train <- d$train$x
y_train <- d$train$y
x_test <- d$test$x
y_test <- d$test$y

# reshape, changing from 28x 28 matrix to 28^2 vector 
dim(x_train)<-c(dim(x_train)[1],28^2) 
dim(x_train)
dim(x_test)<-c(dim(x_test)[1],28^2)
dim(x_test)

#rescale all predictors, makes NNs work better
range(as.vector(x_train))
range(as.vector(x_test)) #So these are integers 0 to 255
# from 255 vector, rescale to 1 
x_train<-x_train/255
x_test<-x_test/255

### model 
# feedforward model / fully connected model
# sequential model as linear stack of layers 
model_1 <- keras_model_sequential(input_shape=784) %>%
    layer_dense(units=256, activation = "relu") %>%
    layer_dropout(rate=0.4) %>%
    layer_dense(units=128, activation ="relu") %>%
    layer_dropout(rate=0.1) %>%
    layer_dense(units=10, activation ="softmax")

model_1$summary()

# let us compile the model 1
model_1 %>% compile(
  loss = 'sparse_categorical_crossentropy',
  optimizer = optimizer_rmsprop(),
  metrics = c('accuracy')
)

### fit the model 
history_1 <- model_1 %>% fit(
  x_train, y_train, 
  epochs = 30, batch_size = 128, 
  validation_split = 0.2)

# Plot and show final values 
png("history_1_plot.png")
plot(history_1)
dev.off()
history_1

# output:
# Final epoch (plot to see history):
#     accuracy: 0.9898
#         loss: 0.03312
# val_accuracy: 0.9813
#     val_loss: 0.09692 


