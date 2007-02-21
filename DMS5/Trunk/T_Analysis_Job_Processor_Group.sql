/****** Object:  Table [dbo].[T_Analysis_Job_Processor_Group] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Analysis_Job_Processor_Group](
	[ID] [int] IDENTITY(100,1) NOT NULL,
	[Group_Name] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Group_Description] [varchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Group_Enabled] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_T_Analysis_Job_Processor_Group_Group_Enabled]  DEFAULT ('Y'),
	[Group_Created] [datetime] NOT NULL CONSTRAINT [DF_T_Analysis_Job_Processor_Group_Group_Created]  DEFAULT (getdate()),
	[Available_For_General_Processing] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_T_Analysis_Job_Processor_Group_Available_For_General_Processing]  DEFAULT ('Y'),
 CONSTRAINT [T_Analysis_Job_Processor_Group_PK] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
) ON [PRIMARY]
) ON [PRIMARY]

GO
