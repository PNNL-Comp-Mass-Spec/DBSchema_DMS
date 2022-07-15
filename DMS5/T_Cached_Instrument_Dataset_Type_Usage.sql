/****** Object:  Table [dbo].[T_Cached_Instrument_Dataset_Type_Usage] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Cached_Instrument_Dataset_Type_Usage](
	[Entry_ID] [int] IDENTITY(1,1) NOT NULL,
	[Instrument_ID] [int] NOT NULL,
	[Dataset_Type] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Dataset_Usage_Count] [int] NULL,
	[Dataset_Usage_Last_Year] [int] NULL,
 CONSTRAINT [PK_T_Cached_Instrument_Dataset_Type_Usage] PRIMARY KEY CLUSTERED 
(
	[Entry_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_Cached_Instrument_Dataset_Type_Usage_Unique_Inst_DS_Type] ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_T_Cached_Instrument_Dataset_Type_Usage_Unique_Inst_DS_Type] ON [dbo].[T_Cached_Instrument_Dataset_Type_Usage]
(
	[Instrument_ID] ASC,
	[Dataset_Type] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
ALTER TABLE [dbo].[T_Cached_Instrument_Dataset_Type_Usage] ADD  CONSTRAINT [DF_T_Cached_Instrument_Dataset_Type_Usage_Dataset_Usage_Count]  DEFAULT ((0)) FOR [Dataset_Usage_Count]
GO
ALTER TABLE [dbo].[T_Cached_Instrument_Dataset_Type_Usage] ADD  CONSTRAINT [DF_T_Cached_Instrument_Dataset_Type_Usage_Dataset_Usage_Last_Year]  DEFAULT ((0)) FOR [Dataset_Usage_Last_Year]
GO
ALTER TABLE [dbo].[T_Cached_Instrument_Dataset_Type_Usage]  WITH CHECK ADD  CONSTRAINT [FK_T_Cached_Instrument_Dataset_Type_Usage_T_Dataset_Type_Name] FOREIGN KEY([Dataset_Type])
REFERENCES [dbo].[T_DatasetTypeName] ([DST_name])
ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[T_Cached_Instrument_Dataset_Type_Usage] CHECK CONSTRAINT [FK_T_Cached_Instrument_Dataset_Type_Usage_T_Dataset_Type_Name]
GO
ALTER TABLE [dbo].[T_Cached_Instrument_Dataset_Type_Usage]  WITH CHECK ADD  CONSTRAINT [FK_T_Cached_Instrument_Dataset_Type_Usage_T_Instrument_Name] FOREIGN KEY([Instrument_ID])
REFERENCES [dbo].[T_Instrument_Name] ([Instrument_ID])
ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[T_Cached_Instrument_Dataset_Type_Usage] CHECK CONSTRAINT [FK_T_Cached_Instrument_Dataset_Type_Usage_T_Instrument_Name]
GO
