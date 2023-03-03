/****** Object:  Table [dbo].[T_Instrument_Group_Allowed_DS_Type] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Instrument_Group_Allowed_DS_Type](
	[IN_Group] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Dataset_Type] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Comment] [varchar](1024) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Dataset_Usage_Count] [int] NULL,
	[Dataset_Usage_Last_Year] [int] NULL,
 CONSTRAINT [PK_T_Instrument_Group_Allowed_DS_Type] PRIMARY KEY CLUSTERED 
(
	[IN_Group] ASC,
	[Dataset_Type] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT VIEW DEFINITION ON [dbo].[T_Instrument_Group_Allowed_DS_Type] TO [DDL_Viewer] AS [dbo]
GO
ALTER TABLE [dbo].[T_Instrument_Group_Allowed_DS_Type] ADD  CONSTRAINT [DF_T_Instrument_Group_Allowed_DS_Type_Comment]  DEFAULT ('') FOR [Comment]
GO
ALTER TABLE [dbo].[T_Instrument_Group_Allowed_DS_Type] ADD  CONSTRAINT [DF_T_Instrument_Group_Allowed_DS_Type_Dataset_Usage_Count]  DEFAULT ((0)) FOR [Dataset_Usage_Count]
GO
ALTER TABLE [dbo].[T_Instrument_Group_Allowed_DS_Type] ADD  CONSTRAINT [DF_T_Instrument_Group_Allowed_DS_Type_Dataset_Usage_Last_Year]  DEFAULT ((0)) FOR [Dataset_Usage_Last_Year]
GO
ALTER TABLE [dbo].[T_Instrument_Group_Allowed_DS_Type]  WITH CHECK ADD  CONSTRAINT [FK_T_Instrument_Group_Allowed_DS_Type_T_Dataset_Type_Name_Dataset_Type] FOREIGN KEY([Dataset_Type])
REFERENCES [dbo].[T_Dataset_Type_Name] ([DST_name])
ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[T_Instrument_Group_Allowed_DS_Type] CHECK CONSTRAINT [FK_T_Instrument_Group_Allowed_DS_Type_T_Dataset_Type_Name_Dataset_Type]
GO
ALTER TABLE [dbo].[T_Instrument_Group_Allowed_DS_Type]  WITH CHECK ADD  CONSTRAINT [FK_T_Instrument_Group_Allowed_DS_Type_T_Instrument_Group_IN_Group] FOREIGN KEY([IN_Group])
REFERENCES [dbo].[T_Instrument_Group] ([IN_Group])
ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[T_Instrument_Group_Allowed_DS_Type] CHECK CONSTRAINT [FK_T_Instrument_Group_Allowed_DS_Type_T_Instrument_Group_IN_Group]
GO
