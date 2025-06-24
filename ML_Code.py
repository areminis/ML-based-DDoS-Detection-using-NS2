
# ML script for Algorithms analysis and comparision

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from xgboost import XGBClassifier
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import LabelEncoder
from sklearn.ensemble import RandomForestClassifier
from sklearn.tree import DecisionTreeClassifier
from sklearn.svm import SVC
from sklearn.neighbors import KNeighborsClassifier
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import accuracy_score, confusion_matrix, classification_report, ConfusionMatrixDisplay, roc_curve, auc

# Load data
data = pd.read_csv('500_busy.csv')

# Encode NodeType
label_enc = LabelEncoder()
data['NodeType'] = label_enc.fit_transform(data['NodeType'])  # Normal=0, Attacker=1, Target=2

# Features and Target
X = data[['PacketsSent', 'PacketsDropped', 'SendRate', 'EnqueueRatio', 'DropRatio']]
y = data['NodeType']

# Remove Target nodes
X = X[y != 2]
y = y[y != 2]

# Drop any NaNs
X = X.dropna()
y = y.loc[X.index]

# Train-Test Split
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

# Models
models = {
    'Random Forest': RandomForestClassifier(random_state=42),
    'Decision Tree': DecisionTreeClassifier(random_state=42),
    'SVM': SVC(kernel='rbf', probability=True, random_state=42),
    'KNN': KNeighborsClassifier(),
    'Logistic Regression': LogisticRegression(max_iter=1000, random_state=42),
    'XGBoost': XGBClassifier(use_label_encoder=False, eval_metric='logloss', random_state=42)
}

results = {}
y_preds = {}

# Training
for name, model in models.items():
    model.fit(X_train, y_train)
    y_pred = model.predict(X_test)
    y_preds[name] = y_pred
    acc = accuracy_score(y_test, y_pred)
    results[name] = acc

    print(f"\n{name} Classification Report:\n")
    print(classification_report(y_test, y_pred))

    # Confusion Matrix
    cm = confusion_matrix(y_test, y_pred)
    disp = ConfusionMatrixDisplay(confusion_matrix=cm, display_labels=['Normal', 'Attacker'])
    disp.plot(cmap='Blues')
    plt.title(f'Confusion Matrix - {name}')
    plt.show()

# Accuracy Comparison - Bar + Line Graph
plt.figure(figsize=(10,6))
plt.bar(results.keys(), results.values(), color='skyblue', label='Accuracy')
plt.plot(results.keys(), list(results.values()), marker='o', color='red', label='Trend')
plt.ylabel('Accuracy')
plt.title('Model Accuracy Comparison')
plt.legend()
plt.grid(True)
plt.xticks(rotation=45)
plt.show()

# Random Forest Feature Importance
rf = RandomForestClassifier(random_state=42)
rf.fit(X_train, y_train)
importances_rf = rf.feature_importances_
indices_rf = np.argsort(importances_rf)[::-1]
features = X.columns

plt.figure(figsize=(10,6))
plt.title('Random Forest Feature Importance')
plt.bar(features[indices_rf], importances_rf[indices_rf], color='lightgreen')
plt.xticks(rotation=45)
plt.show()


# SendRate vs DropRatio
sns.scatterplot(data=X.assign(NodeType=label_enc.inverse_transform(y)), x='SendRate', y='DropRatio', hue='NodeType')
plt.title('SendRate vs DropRatio (Feature Tradeoff)')
plt.grid(True)
plt.show()

# PacketsSent vs EnqueueRatio
sns.scatterplot(data=X.assign(NodeType=label_enc.inverse_transform(y)), x='PacketsSent', y='EnqueueRatio', hue='NodeType')
plt.title('PacketsSent vs EnqueueRatio (Feature Tradeoff)')
plt.grid(True)
plt.show()

# PacketsDropped vs DropRatio
sns.scatterplot(data=X.assign(NodeType=label_enc.inverse_transform(y)), x='PacketsDropped', y='DropRatio', hue='NodeType')
plt.title('PacketsDropped vs DropRatio (Feature Tradeoff)')
plt.grid(True)
plt.show()

# ROC Curves for all models
plt.figure(figsize=(10,7))
for name, model in models.items():
    if hasattr(model, "predict_proba"):
        y_score = model.predict_proba(X_test)[:, 1]
    else:
        y_score = model.decision_function(X_test)

    fpr, tpr, _ = roc_curve(y_test, y_score)
    roc_auc = auc(fpr, tpr)
    plt.plot(fpr, tpr, lw=2, label=f'{name} (AUC = {roc_auc:.2f})')

plt.plot([0,1], [0,1], linestyle='--', color='grey')
plt.xlabel('False Positive Rate')
plt.ylabel('True Positive Rate')
plt.title('ROC Curve Comparison')
plt.legend()

plt.grid(True)
plt.show()