/****** Object:  Table [dbo].[T_Machines] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Machines](
	[Machine] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Total_CPUs] [tinyint] NOT NULL,
	[CPUs_Available] [int] NOT NULL,
	[Total_Memory_MB] [int] NOT NULL,
	[Memory_Available] [int] NOT NULL,
	[ProcTool_Group_ID] [int] NOT NULL,
	[Comment] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_T_Machines] PRIMARY KEY CLUSTERED 
(
	[Machine] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
ALTER TABLE [dbo].[T_Machines] ADD  CONSTRAINT [DF_T_Machines_Total_CPUs]  DEFAULT ((2)) FOR [Total_CPUs]
GO
ALTER TABLE [dbo].[T_Machines] ADD  CONSTRAINT [DF_T_Machines_CPUs_Available]  DEFAULT ((0)) FOR [CPUs_Available]
GO
ALTER TABLE [dbo].[T_Machines] ADD  CONSTRAINT [DF_T_Machines_Total_Memory_MB]  DEFAULT ((4000)) FOR [Total_Memory_MB]
GO
ALTER TABLE [dbo].[T_Machines] ADD  CONSTRAINT [DF_T_Machines_Memory_Available]  DEFAULT ((4000)) FOR [Memory_Available]
GO
ALTER TABLE [dbo].[T_Machines] ADD  CONSTRAINT [DF_T_Machines_ProcTool_Group_ID]  DEFAULT ((0)) FOR [ProcTool_Group_ID]
GO
ALTER TABLE [dbo].[T_Machines]  WITH CHECK ADD  CONSTRAINT [FK_T_Machines_T_Processor_Tool_Groups] FOREIGN KEY([ProcTool_Group_ID])
REFERENCES [dbo].[T_Processor_Tool_Groups] ([Group_ID])
ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[T_Machines] CHECK CONSTRAINT [FK_T_Machines_T_Processor_Tool_Groups]
GO
