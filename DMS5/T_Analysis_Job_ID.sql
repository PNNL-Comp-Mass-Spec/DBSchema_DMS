/****** Object:  Table [dbo].[T_Analysis_Job_ID] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Analysis_Job_ID](
	[ID] [int] IDENTITY(522434,1) NOT NULL,
	[Note] [varchar](256) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Created] [datetime] NOT NULL,
 CONSTRAINT [PK_T_Analysis_Job_ID] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
ALTER TABLE [dbo].[T_Analysis_Job_ID] ADD  CONSTRAINT [DF_T_Analysis_Job_ID_Created]  DEFAULT (getdate()) FOR [Created]
GO
