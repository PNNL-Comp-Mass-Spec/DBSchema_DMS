/****** Object:  Table [dbo].[T_Cached_Instrument_Dataset_Type_Usage] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Cached_Instrument_Dataset_Type_Usage](
	[Instrument_ID] [int] NOT NULL,
	[Dataset_Type] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Dataset_Usage_Count] [int] NULL,
	[Dataset_Usage_Last_Year] [int] NULL,
 CONSTRAINT [PK_T_Cached_Instrument_Dataset_Type_Usage] PRIMARY KEY CLUSTERED 
(
	[Instrument_ID] ASC,
	[Dataset_Type] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

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
