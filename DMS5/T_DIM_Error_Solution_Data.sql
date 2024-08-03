/****** Object:  Table [T_DIM_Error_Solution] ******/
/****** RowCount: 10 ******/
/****** Columns: Error_Text, Solution ******/
INSERT INTO [T_DIM_Error_Solution] VALUES ('A Proposal ID and associated users must be selected','No proposal ID provided:
Obtain proposal ID from DMS
Search requests for this dataset
https://dms2.pnl.gov/scheduled_run/report')
INSERT INTO [T_DIM_Error_Solution] VALUES ('already in database','Dataset with that name is already in the database:
Check to confirm the dataset already uploaded
If this is a new dataset, change the name to reflect different data
https://dms2.pnl.gov/dataset/report')
INSERT INTO [T_DIM_Error_Solution] VALUES ('Could not find entry in database for experiment','Experiment name not valid:
Check name for errors
If the name is correct, enter new experiment name in DMS
https://dms2.pnl.gov/experiment/report')
INSERT INTO [T_DIM_Error_Solution] VALUES ('Could not resolve column number to ID','Column name not in DMS:
Check the column name
Enter a new column in DMS
https://dms2.pnl.gov/lc_column/report')
INSERT INTO [T_DIM_Error_Solution] VALUES ('Could not resolve EUS usage type','EMSL user information not provided:
Fill out Usage Type (e.g. User_Onsite, User_Remote, Cap_Dev, or Maintenance)
If Usage Type is "User" also provide User Number and Proposal Number

Get EMSL User information from DMS by looking at a similar request
https://dms2.pnl.gov/eus_proposals/report')
INSERT INTO [T_DIM_Error_Solution] VALUES ('Could not verify EUS proposal ID','Proposal ID is not valid:
Get correct ID from DMS
Search requests for this dataset
https://dms2.pnl.gov/scheduled_run/report')
INSERT INTO [T_DIM_Error_Solution] VALUES ('Dataset name may not contain spaces','Dataset entered contains spaces:
Please check dataset name and experiment name for spaces')
INSERT INTO [T_DIM_Error_Solution] VALUES ('Operator payroll number/HID was blank','Operator payroll number not provided:
Provide Operator payroll number')
INSERT INTO [T_DIM_Error_Solution] VALUES ('Request ID not found','Request Number Not Valid: 
Check request number against DMS request page
https://dms2.pnl.gov/scheduled_run/report
If this is a rerun the request might have already been used, or is waiting to be dispositioned
If no request is found upload the dataset with a "0" request number and provided appropriate Usage Type, User Number and Proposal')
INSERT INTO [T_DIM_Error_Solution] VALUES ('The dataset data is not available for capture','Dataset not found in instrument transfer folder; possible causes:

(1) Difference between Xcalibur queue and LCMS queue (i.e. Check the date in dataset name)
(2) Cart is running and the Mass Spectrometer is not running
(3) Wrong directory on instrument selected, datasets being saved in another folder
(4) Name of dataset changed (e.g. bad_ or marg_) before upload')
