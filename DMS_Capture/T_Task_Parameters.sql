/****** Object:  Table [dbo].[T_Task_Parameters] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Task_Parameters](
	[Job] [int] NOT NULL,
	[Parameters] [xml] NULL,
 CONSTRAINT [PK_T_Task_Parameters] PRIMARY KEY CLUSTERED 
(
	[Job] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
GRANT VIEW DEFINITION ON [dbo].[T_Task_Parameters] TO [DDL_Viewer] AS [dbo]
GO
ALTER TABLE [dbo].[T_Task_Parameters]  WITH CHECK ADD  CONSTRAINT [FK_T_Task_Parameters_T_Tasks] FOREIGN KEY([Job])
REFERENCES [dbo].[T_Tasks] ([Job])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[T_Task_Parameters] CHECK CONSTRAINT [FK_T_Task_Parameters_T_Tasks]
GO
