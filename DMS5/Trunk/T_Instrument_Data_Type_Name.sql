/****** Object:  Table [dbo].[T_Instrument_Data_Type_Name] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Instrument_Data_Type_Name](
	[Raw_Data_Type_ID] [int] IDENTITY(1,1) NOT NULL,
	[Raw_Data_Type_Name] [varchar](32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Is_Folder] [tinyint] NOT NULL,
	[Required_File_Extension] [varchar](12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Comment] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_T_Instrument_Data_Type_Name] PRIMARY KEY CLUSTERED 
(
	[Raw_Data_Type_ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 10) ON [PRIMARY]
) ON [PRIMARY]

GO

/****** Object:  Index [IX_T_Instrument_Data_Type_Name] ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_T_Instrument_Data_Type_Name] ON [dbo].[T_Instrument_Data_Type_Name] 
(
	[Raw_Data_Type_Name] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 10) ON [PRIMARY]
GO
ALTER TABLE [dbo].[T_Instrument_Data_Type_Name] ADD  CONSTRAINT [DF_T_Instrument_Data_Type_Name_Is_Folder]  DEFAULT ((0)) FOR [Is_Folder]
GO
ALTER TABLE [dbo].[T_Instrument_Data_Type_Name] ADD  CONSTRAINT [DF_T_Instrument_Data_Type_Name_Required_File_Extension]  DEFAULT ('') FOR [Required_File_Extension]
GO
