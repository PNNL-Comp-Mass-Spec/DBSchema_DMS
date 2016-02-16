/****** Object:  Table [dbo].[T_Local_Processor_Job_Step_Exclusion] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Local_Processor_Job_Step_Exclusion](
	[ID] [int] NOT NULL,
	[Step] [int] NOT NULL,
 CONSTRAINT [PK_T_Local_Processor_Job_Step_Exclusion] PRIMARY KEY CLUSTERED 
(
	[ID] ASC,
	[Step] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
