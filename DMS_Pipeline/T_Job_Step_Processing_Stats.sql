/****** Object:  Table [dbo].[T_Job_Step_Processing_Stats] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Job_Step_Processing_Stats](
	[Entered] [smalldatetime] NOT NULL,
	[Job] [int] NOT NULL,
	[Step] [int] NOT NULL,
	[Processor] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[RunTime_Minutes] [decimal](9, 1) NULL,
	[Job_Progress] [real] NULL,
	[RunTime_Predicted_Hours] [decimal](9, 2) NULL,
	[ProgRunner_CoreUsage] [real] NULL,
	[CPU_Load] [tinyint] NULL,
	[Actual_CPU_Load] [tinyint] NULL,
 CONSTRAINT [PK_T_Job_Step_Processing_Stats] PRIMARY KEY CLUSTERED 
(
	[Entered] ASC,
	[Job] ASC,
	[Step] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
