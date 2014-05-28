/****** Object:  Table [dbo].[T_Instrument_Group_Allowed_DS_Type] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Instrument_Group_Allowed_DS_Type](
	[IN_Group] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Dataset_Type] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Comment] [varchar](1024) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_T_Instrument_Group_Allowed_DS_Type] PRIMARY KEY CLUSTERED 
(
	[IN_Group] ASC,
	[Dataset_Type] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
ALTER TABLE [dbo].[T_Instrument_Group_Allowed_DS_Type] ADD  CONSTRAINT [DF_T_Instrument_Group_Allowed_DS_Type_Comment]  DEFAULT ('') FOR [Comment]
GO
ALTER TABLE [dbo].[T_Instrument_Group_Allowed_DS_Type]  WITH CHECK ADD  CONSTRAINT [FK_T_Instrument_Group_Allowed_DS_Type_T_DatasetTypeName_Dataset_Type] FOREIGN KEY([Dataset_Type])
REFERENCES [dbo].[T_DatasetTypeName] ([DST_name])
ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[T_Instrument_Group_Allowed_DS_Type] CHECK CONSTRAINT [FK_T_Instrument_Group_Allowed_DS_Type_T_DatasetTypeName_Dataset_Type]
GO
ALTER TABLE [dbo].[T_Instrument_Group_Allowed_DS_Type]  WITH CHECK ADD  CONSTRAINT [FK_T_Instrument_Group_Allowed_DS_Type_T_Instrument_Group_IN_Group] FOREIGN KEY([IN_Group])
REFERENCES [dbo].[T_Instrument_Group] ([IN_Group])
ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[T_Instrument_Group_Allowed_DS_Type] CHECK CONSTRAINT [FK_T_Instrument_Group_Allowed_DS_Type_T_Instrument_Group_IN_Group]
GO
