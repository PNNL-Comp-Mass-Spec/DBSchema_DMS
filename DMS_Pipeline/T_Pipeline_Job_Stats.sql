/****** Object:  Table [dbo].[T_Pipeline_Job_Stats] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Pipeline_Job_Stats](
	[Script] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Instrument_Group] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Year] [int] NOT NULL,
	[Jobs] [int] NOT NULL,
 CONSTRAINT [PK_T_Pipeline_Job_Stats] PRIMARY KEY CLUSTERED 
(
	[Script] ASC,
	[Instrument_Group] ASC,
	[Year] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
