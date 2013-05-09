/****** Object:  Table [dbo].[T_Job_Parameters_History] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Job_Parameters_History](
	[Job] [int] NOT NULL,
	[Parameters] [xml] NULL,
	[Saved] [datetime] NOT NULL,
 CONSTRAINT [PK_T_Job_Parameters_History] PRIMARY KEY CLUSTERED 
(
	[Job] ASC,
	[Saved] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
