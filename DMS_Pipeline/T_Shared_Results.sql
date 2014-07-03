/****** Object:  Table [dbo].[T_Shared_Results] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Shared_Results](
	[Results_Name] [varchar](256) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Created] [datetime] NOT NULL,
 CONSTRAINT [PK_T_Shared_Results_1] PRIMARY KEY CLUSTERED 
(
	[Results_Name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
ALTER TABLE [dbo].[T_Shared_Results] ADD  CONSTRAINT [DF_T_Shared_Results_Created]  DEFAULT (getdate()) FOR [Created]
GO
