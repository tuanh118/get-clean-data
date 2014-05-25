# Download and unzip to ./data/UCI HAR Dataset/

# Read data description

# 1 - Merges the training and the test sets to create one data set

## Loading data sets
train <- read.table("./data/UCI HAR Dataset/train/X_train.txt")
str(train)

test <- read.table("./data/UCI HAR Dataset/test/X_test.txt")

## Add into one big set
dataset <- rbind(train, test)
nrow(dataset)

# 2 - Extracts only the measurements on the mean and standard deviation for each measurement

## Feature/variable names
features <- read.table("./data/UCI HAR Dataset/features.txt", stringsAsFactor=F)
colnames(features) <- c("num", "name")
str(features)

## Getting measurements on Mean and Standard deviation
##  based on feature names
features.limited <- features[(grepl("mean()", features$name) | grepl("std()", features$name)), ]

### Exclude meanFreq()
features.limited <- features.limited[!grepl("meanFreq()", features.limited$name), ]
str(features.limited)

## Extract above measurements from the big data set
dataset.limited <- dataset[, features.limited$num]

## Set new names
colnames(dataset.limited) <- features.limited$name

## Adding subject id to each row
subject.train <- read.table("./data/UCI HAR Dataset/train/subject_train.txt")
subject.test <- read.table("./data/UCI HAR Dataset/test/subject_test.txt")
dataset.limited$subject <- rbind(subject.train, subject.test)$V1

## Look at the data frame
str(dataset.limited)

# 3 - Uses descriptive activity names to name the activities in the data set

## Adding activity label to each row
label.train <- read.table("./data/UCI HAR Dataset/train/y_train.txt")
label.test <- read.table("./data/UCI HAR Dataset/test/y_test.txt")
dataset.limited$label <- rbind(label.train, label.test)$V1

## Match the activity numbers with appropriate activity names provided

### Read in activity labels
activity.names <- read.table("./data/UCI HAR Dataset/activity_labels.txt")
str(activity.names)

### Merge the two data sets to get the label names
dataset.limited <- merge(dataset.limited, activity.names, by.x="label", by.y="V1", all=T)

### Remove label number field and rename new field
dataset.limited$label <- NULL
colnames(dataset.limited)[68] <- "activitylabels"

### Refine factor level names
levels(dataset.limited$activitylabels) <- tolower(levels(dataset.limited$activitylabels))
levels(dataset.limited$activitylabels) <- sub("_", "", levels(dataset.limited$activitylabels))

## Sort the dataset by subject id and then by activity name
dataset.limited <- dataset.limited[order(dataset.limited$subject, dataset.limited$activitylabels), ]

# 4 - Appropriately labels the data set with descriptive column names
source("featureNameRefine.R")
colnames(dataset.limited) <- sapply(colnames(dataset.limited), featureNameRefine)

# 5 - Creates a second, independent tidy data set with the 
#   average of each variable for each activity and each subject.
tidy <- dataset.limited
tidy$activitylabels <- as.character(tidy$activitylabels)

## Group the observations by subject and activity (180 groups = 30 subjects * 6 activities)
tidy$group <- paste(tidy$subject, tidy$activitylabels)
tidy$group <- as.factor(tidy$group)

## Create the final tidy data frame
tidyset=data.frame(1:180)

## Iteratively add each feature/field to the data frame
for (i in 1:66) {
    tidyset[, colnames(tidy)[i]] <- tapply(tidy[, i], tidy$group, mean)
}

## Rename each row to corresponding group name
rownames(tidyset) <- unique(tidy$group)

## Unnecessary variable
tidyset[, 1] <- NULL
dim(tidyset)
head(tidyset, 3)

## Export the tidy set
write.table(tidyset, file="tidy.txt", sep="\t")