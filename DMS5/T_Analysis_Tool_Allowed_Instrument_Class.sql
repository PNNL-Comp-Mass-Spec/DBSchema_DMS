/****** Object:  Table [dbo].[T_Analysis_Tool_Allowed_Instrument_Class] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Analysis_Tool_Allowed_Instrument_Class](
	[Analysis_Tool_ID] [int] NOT NULL,
	[Instrument_Class] [varchar](32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Comment] [varchar](1024) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_T_Analysis_Tool_Allowed_Instrument_Class] PRIMARY KEY CLUSTERED 
(
	[Analysis_Tool_ID] ASC,
	[Instrument_Class] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT VIEW DEFINITION ON [dbo].[T_Analysis_Tool_Allowed_Instrument_Class] TO [DDL_Viewer] AS [dbo]
GO
ALTER TABLE [dbo].[T_Analysis_Tool_Allowed_Instrument_Class] ADD  CONSTRAINT [DF_T_Analysis_Tool_Allowed_Instrument_Class_Comment]  DEFAULT ('') FOR [Comment]
GO
ALTER TABLE [dbo].[T_Analysis_Tool_Allowed_Instrument_Class]  WITH CHECK ADD  CONSTRAINT [FK_T_Analysis_Tool_Allowed_Instrument_Class_T_Analysis_Tool] FOREIGN KEY([Analysis_Tool_ID])
REFERENCES [dbo].[T_Analysis_Tool] ([AJT_toolID])
ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[T_Analysis_Tool_Allowed_Instrument_Class] CHECK CONSTRAINT [FK_T_Analysis_Tool_Allowed_Instrument_Class_T_Analysis_Tool]
GO
ALTER TABLE [dbo].[T_Analysis_Tool_Allowed_Instrument_Class]  WITH CHECK ADD  CONSTRAINT [FK_T_Analysis_Tool_Allowed_Instrument_Class_T_Instrument_Class] FOREIGN KEY([Instrument_Class])
REFERENCES [dbo].[T_Instrument_Class] ([IN_class])
ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[T_Analysis_Tool_Allowed_Instrument_Class] CHECK CONSTRAINT [FK_T_Analysis_Tool_Allowed_Instrument_Class_T_Instrument_Class]
GO
