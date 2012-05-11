/****** Object:  Table [dbo].[T_Instrument_Allowed_Dataset_Type] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Instrument_Allowed_Dataset_Type](
	[Instrument] [varchar](24) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Dataset_Type] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Comment] [varchar](1024) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_T_Instrument_Allowed_Dataset_Type] PRIMARY KEY CLUSTERED 
(
	[Instrument] ASC,
	[Dataset_Type] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 10) ON [PRIMARY]
) ON [PRIMARY]

GO
ALTER TABLE [dbo].[T_Instrument_Allowed_Dataset_Type]  WITH CHECK ADD  CONSTRAINT [FK_T_Instrument_Allowed_Dataset_Type_T_DatasetTypeName] FOREIGN KEY([Dataset_Type])
REFERENCES [T_DatasetTypeName] ([DST_name])
ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[T_Instrument_Allowed_Dataset_Type] CHECK CONSTRAINT [FK_T_Instrument_Allowed_Dataset_Type_T_DatasetTypeName]
GO
ALTER TABLE [dbo].[T_Instrument_Allowed_Dataset_Type]  WITH CHECK ADD  CONSTRAINT [FK_T_Instrument_Allowed_Dataset_Type_T_Instrument_Name] FOREIGN KEY([Instrument])
REFERENCES [T_Instrument_Name] ([IN_name])
GO
ALTER TABLE [dbo].[T_Instrument_Allowed_Dataset_Type] CHECK CONSTRAINT [FK_T_Instrument_Allowed_Dataset_Type_T_Instrument_Name]
GO
ALTER TABLE [dbo].[T_Instrument_Allowed_Dataset_Type] ADD  CONSTRAINT [DF_T_Instrument_Allowed_Dataset_Type_Comment]  DEFAULT ('') FOR [Comment]
GO
