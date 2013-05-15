/****** Object:  Table [dbo].[T_Instrument_Group] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Instrument_Group](
	[IN_Group] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Usage] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Comment] [varchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Active] [tinyint] NOT NULL,
	[Default_Dataset_Type] [int] NULL,
	[Allocation_Tag] [varchar](24) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_T_Instrument_Group] PRIMARY KEY CLUSTERED 
(
	[IN_Group] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
ALTER TABLE [dbo].[T_Instrument_Group]  WITH CHECK ADD  CONSTRAINT [FK_T_Instrument_Group_T_DatasetTypeName] FOREIGN KEY([Default_Dataset_Type])
REFERENCES [T_DatasetTypeName] ([DST_Type_ID])
GO
ALTER TABLE [dbo].[T_Instrument_Group] CHECK CONSTRAINT [FK_T_Instrument_Group_T_DatasetTypeName]
GO
ALTER TABLE [dbo].[T_Instrument_Group]  WITH CHECK ADD  CONSTRAINT [FK_T_Instrument_Group_T_Instrument_Group_Allocation_Tag] FOREIGN KEY([Allocation_Tag])
REFERENCES [T_Instrument_Group_Allocation_Tag] ([Allocation_Tag])
GO
ALTER TABLE [dbo].[T_Instrument_Group] CHECK CONSTRAINT [FK_T_Instrument_Group_T_Instrument_Group_Allocation_Tag]
GO
ALTER TABLE [dbo].[T_Instrument_Group] ADD  CONSTRAINT [DF_T_Instrument_Group_Usage]  DEFAULT ('') FOR [Usage]
GO
ALTER TABLE [dbo].[T_Instrument_Group] ADD  CONSTRAINT [DF_T_Instrument_Group_Comment]  DEFAULT ('') FOR [Comment]
GO
ALTER TABLE [dbo].[T_Instrument_Group] ADD  CONSTRAINT [DF_T_Instrument_Group_Active]  DEFAULT ((1)) FOR [Active]
GO
