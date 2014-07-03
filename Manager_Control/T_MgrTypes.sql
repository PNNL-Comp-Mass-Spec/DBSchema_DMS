/****** Object:  Table [dbo].[T_MgrTypes] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_MgrTypes](
	[MT_TypeID] [int] IDENTITY(1,1) NOT NULL,
	[MT_TypeName] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[MT_Active] [tinyint] NOT NULL,
 CONSTRAINT [PK_T_MgrTypes] PRIMARY KEY CLUSTERED 
(
	[MT_TypeID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
ALTER TABLE [dbo].[T_MgrTypes] ADD  CONSTRAINT [DF_T_MgrTypes_MT_Active]  DEFAULT ((1)) FOR [MT_Active]
GO
