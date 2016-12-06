/****** Object:  Table [dbo].[T_Run_Interval] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Run_Interval](
	[ID] [int] NOT NULL,
	[Instrument] [varchar](24) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Start] [datetime] NULL,
	[Interval] [int] NULL,
	[Comment] [varchar](max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Usage] [xml] NULL,
	[Entered] [datetime] NULL,
	[Last_Affected] [datetime] NULL,
	[Entered_By] [varchar](256) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_T_Run_Interval] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
GRANT VIEW DEFINITION ON [dbo].[T_Run_Interval] TO [DDL_Viewer] AS [dbo]
GO
ALTER TABLE [dbo].[T_Run_Interval] ADD  CONSTRAINT [DF_T_Run_Interval_Entered]  DEFAULT (getdate()) FOR [Entered]
GO
ALTER TABLE [dbo].[T_Run_Interval] ADD  CONSTRAINT [DF_T_Run_Interval_Last_Affected]  DEFAULT (getdate()) FOR [Last_Affected]
GO
ALTER TABLE [dbo].[T_Run_Interval] ADD  CONSTRAINT [DF_T_Run_Interval_Entered_By]  DEFAULT (suser_sname()) FOR [Entered_By]
GO
