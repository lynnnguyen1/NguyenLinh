# NguyenLinh
Linh's repo for BIOL 701, Fall 2026 

# Assignments
## Unit 1 (Unit01_Git)
- Added Ceren to be my collaborator in this repo (for Unit01_Git folder)
- Push and pull commands. Also playing around with git 

## Unit 3 (Unit03_CART)
### General info

- Working on breast cancer database: https://www.kaggle.com/datasets/uciml/breast-cancer-wisconsin-data?resource=download, but the data was unzipped as "data.csv"
- Also, I downloaded https://archive.ics.uci.edu/dataset/1/abalone and stored as abalone_data.csv 

Variables that we have in this dataset:
- target of prediction: sex
- features: 
length, diameter, height, whole_weight, shucked weight,viscera_weight, shell weight, rings

In this unit: 
- fit pre-pruned tree and full tree in the training set
- cross validation, in both mannual way and less-mannual way
- pruning the tree before fitting
- bagging
- random forest
- boosting 
- along with validation after each steps 
- also test on test data 

### Unit summary
I examined how to classify three different sexes of abalone (male (M), female (F), or intersex (I, which was for infant with no clear sign of sex)). There are 4176 entries spread out to 8 different measurements of an abalone, and the first column is the identified sex. Initial dataset were splitted into train_set (70%, 3132 entries) and test_set (30%, 1044 entries). Seven models were trained and validated using cross-validation on train_set, and random forest is the best model with lowest error rate on train dataset (45.02%). Then, its performance was examined on test set and reached the error rate of 42.82%. 

Table 1: Summary of models error rates


| Model       | Error Rate |
|-------------|------------|
| Full CART model  | 0.505125   |
| Pruned CART model| 0.4693616  |
| New model   | 0.4623461  |
| Bagging     | 0.4626615  |
| Random forest| 0.4502096 |
| Adaptive boost   | 0.4677622  |
| XGBoost     | 0.6596508  |

With error rate on test set is slightly lower than on train set, it means that there is low chance that our trained random forest model was overfitting or performing random guess (accuracy not 0.5). Biologically speaking, if we just based on morphologies of abalone as a marker and fit a random forest model to predict its sex (male, female or intersex), our model will predict wrong ~43% of the time, which is not really bad but also not really good. It can be because of the intersex classification (I), which was used when they got an infant abalone and not sure its sex yet, so maybe removing I class can help with prediction.  
