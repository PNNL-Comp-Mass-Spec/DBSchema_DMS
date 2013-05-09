/****** Object:  Table [dbo].[T_Processor_Tool_Groups] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Processor_Tool_Groups](
	[Group_ID] [int] NOT NULL,
	[Group_Name] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Enabled] [smallint] NOT NULL,
	[Comment] [varchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 CONSTRAINT [PK_T_Processor_Tool_Groups] PRIMARY KEY CLUSTERED 
(
	[Group_ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 100) ON [PRIMARY]
) ON [PRIMARY]

GO
ALTER TABLE [dbo].[T_Processor_Tool_Groups] ADD  CONSTRAINT [DF_T_Processor_Tool_Groups_Enabled]  DEFAULT ((1)) FOR [Enabled]
GO
ALTER TABLE [dbo].[T_Processor_Tool_Groups] ADD  CONSTRAINT [DF_T_Processor_Tool_Groups_Comment]  DEFAULT ('') FOR [Comment]
GO
