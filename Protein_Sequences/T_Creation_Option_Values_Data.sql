/****** Object:  Table [T_Creation_Option_Values] ******/
/****** RowCount: 7 ******/
SET IDENTITY_INSERT [T_Creation_Option_Values] ON
INSERT INTO [T_Creation_Option_Values] (Value_ID, Value_String, Display, Description, Keyword_ID) VALUES (1,'forward','Forward','Sequences as read from the database',1)
INSERT INTO [T_Creation_Option_Values] (Value_ID, Value_String, Display, Description, Keyword_ID) VALUES (2,'reversed','Reversed','Sequences character reversed',1)
INSERT INTO [T_Creation_Option_Values] (Value_ID, Value_String, Display, Description, Keyword_ID) VALUES (3,'scrambled','Scrambled','Sequences randomized within a protein',1)
INSERT INTO [T_Creation_Option_Values] (Value_ID, Value_String, Display, Description, Keyword_ID) VALUES (4,'fasta','Standard FASTA','Standard FASTA file in ASCII text format',2)
INSERT INTO [T_Creation_Option_Values] (Value_ID, Value_String, Display, Description, Keyword_ID) VALUES (5,'fastapro','FASTA.pro file for X!Tandem','The FASTA.pro file is a binary form of an original FASTA file',2)
INSERT INTO [T_Creation_Option_Values] (Value_ID, Value_String, Display, Description, Keyword_ID) VALUES (8,'decoy','Decoy','Combined Forward/Reverse FASTA file',1)
INSERT INTO [T_Creation_Option_Values] (Value_ID, Value_String, Display, Description, Keyword_ID) VALUES (9,'decoyX','DecoyX','Combined Forward/Reverse FASTA file using XXX.',1)
SET IDENTITY_INSERT [T_Creation_Option_Values] OFF
