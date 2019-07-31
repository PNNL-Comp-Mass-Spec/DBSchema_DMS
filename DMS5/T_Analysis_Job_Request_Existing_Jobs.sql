/****** Object:  Table [dbo].[T_Analysis_Job_Request_Existing_Jobs] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Analysis_Job_Request_Existing_Jobs](
	[Request_ID] [int] NOT NULL,
	[Job] [int] NOT NULL,
 CONSTRAINT [PK_T_Analysis_Job_Request_Existing_Jobs] PRIMARY KEY CLUSTERED 
(
	[Request_ID] ASC,
	[Job] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
