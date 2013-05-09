/****** Object:  Table [dbo].[T_Machines] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Machines](
	[Machine] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Total_CPUs] [tinyint] NOT NULL,
	[CPUs_Available] [int] NOT NULL,
	[Bionet_Available] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 CONSTRAINT [PK_T_Machines] PRIMARY KEY CLUSTERED 
(
	[Machine] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 100) ON [PRIMARY]
) ON [PRIMARY]

GO
ALTER TABLE [dbo].[T_Machines] ADD  CONSTRAINT [DF_T_Machines_Total_CPUs]  DEFAULT ((2)) FOR [Total_CPUs]
GO
ALTER TABLE [dbo].[T_Machines] ADD  CONSTRAINT [DF_T_Machines_CPUs_Available]  DEFAULT ((0)) FOR [CPUs_Available]
GO
ALTER TABLE [dbo].[T_Machines] ADD  CONSTRAINT [DF_T_Machines_Bionet_Available]  DEFAULT ('N') FOR [Bionet_Available]
GO
