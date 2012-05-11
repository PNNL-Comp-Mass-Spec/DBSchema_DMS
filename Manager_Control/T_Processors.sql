/****** Object:  Table [dbo].[T_Processors] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Processors](
	[Processor_Name] [varchar](32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Speed_GHz] [decimal](9, 4) NOT NULL,
	[FSB_MHz] [decimal](9, 2) NULL,
	[CPU_Count] [tinyint] NOT NULL,
	[Comment] [varchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Active] [tinyint] NOT NULL,
	[Created] [datetime] NOT NULL,
	[Last_Affected] [datetime] NOT NULL,
 CONSTRAINT [PK_T_Processors] PRIMARY KEY CLUSTERED 
(
	[Processor_Name] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
ALTER TABLE [dbo].[T_Processors] ADD  CONSTRAINT [DF_T_Processors_Comment]  DEFAULT ('') FOR [Comment]
GO
ALTER TABLE [dbo].[T_Processors] ADD  CONSTRAINT [DF_T_Processors_Active]  DEFAULT ((0)) FOR [Active]
GO
ALTER TABLE [dbo].[T_Processors] ADD  CONSTRAINT [DF_T_Processors_Created]  DEFAULT (getdate()) FOR [Created]
GO
ALTER TABLE [dbo].[T_Processors] ADD  CONSTRAINT [DF_T_Processors_Last_Affected]  DEFAULT (getdate()) FOR [Last_Affected]
GO
