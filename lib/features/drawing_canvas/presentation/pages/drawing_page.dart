import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xournalpp_web/features/drawing_canvas/domain/entities/drawing_tool.dart';
import 'package:xournalpp_web/features/drawing_canvas/presentation/bloc/drawing_cubit.dart';
import 'package:xournalpp_web/features/drawing_canvas/presentation/bloc/drawing_state.dart';
import 'package:xournalpp_web/features/drawing_canvas/presentation/widgets/drawing_canvas.dart';
import 'package:xournalpp_web/features/file_management/data/datasources/local_file_data_source.dart';
import 'package:xournalpp_web/features/file_management/data/repositories/file_repository_impl.dart';
import 'package:xournalpp_web/features/file_management/domain/usecases/export_pdf_file.dart';
import 'package:xournalpp_web/features/file_management/domain/usecases/open_xopp_file.dart';
import 'package:xournalpp_web/features/file_management/domain/usecases/save_xopp_file.dart';


class DrawingPage extends StatelessWidget {
  const DrawingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final localFileDataSource = LocalFileDataSourceImpl();
    final fileRepository = FileRepositoryImpl(localFileDataSource);
    final openXoppFile = OpenXoppFile(fileRepository);
    final saveXoppFile = SaveXoppFile(fileRepository);
    final exportPdfFile = ExportPdfFile(fileRepository);
    return BlocProvider(
      create: (context) => DrawingCubit(
        openXoppFile: openXoppFile,
        saveXoppFile: saveXoppFile,
        exportPdfFile: exportPdfFile,
      ),
      child: const DrawingView(),
    );
  }
}

class DrawingView extends StatelessWidget {
  const DrawingView({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<DrawingCubit>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Xournal++ Web'),
        backgroundColor: Theme.of(context).primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.file_open),
            onPressed: () async {
              await cubit.openFile();
            }, 
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () async {
              await cubit.saveFile();
            }
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () async {
              await cubit.exportPdf();
            }
          ),
          BlocBuilder<DrawingCubit, DrawingState>(
            buildWhen: (previous, current) => previous.currentTool != current.currentTool,
            builder: (context, state) {
              return IconButton(
                icon: Icon(Icons.arrow_back_ios),
                onPressed: state.currentPageIndex > 0 ? () => cubit.previousPage() : null,
                );
            },
          ),
          BlocBuilder<DrawingCubit, DrawingState>(
            buildWhen: (previous, current) => 
                previous.currentPageIndex != current.currentPageIndex || 
                previous.currentDocument?.pages.length != current.currentDocument?.pages.length,
            builder: (context, state) {
              return Center(
                child: Text(
                  state.currentDocument != null 
                      ? '${state.currentPageIndex + 1} / ${state.currentDocument!.pages.length}'
                      : '1 / 1',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              );
            },
          ),
          BlocBuilder<DrawingCubit, DrawingState>(
            buildWhen: (previous, current) => previous.currentPageIndex != current.currentPageIndex || previous.currentDocument?.pages.length != current.currentDocument?.pages.length,
            builder: (context, state) {
              return IconButton(
                icon: const Icon(Icons.arrow_forward_ios),
                onPressed: state.currentDocument != null && state.currentPageIndex < state.currentDocument!.pages.length - 1 
                    ? () => cubit.nextPage() 
                    : null,
              );
            },
          ),
          BlocBuilder<DrawingCubit, DrawingState>(
            buildWhen: (previous, current) => previous.currentTool != current.currentTool,
            builder: (context, state) {
              return PopupMenuButton<DrawingTool>(
                icon: Icon(
                  state.currentTool == DrawingTool.pen ? Icons.edit : Icons.cleaning_services,
                  color: Colors.white,
                ),
                onSelected: (tool) => cubit.changeTool(tool),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: DrawingTool.pen,
                    child: Text('Caneta'),
                  ),
                  const PopupMenuItem(
                    value: DrawingTool.eraser,
                    child: Text('Borracha'),
                  ),
                ],
              );
            },
          ),
          BlocBuilder<DrawingCubit, DrawingState>(
            buildWhen: (previous, current) => previous.currentColor != current.currentColor,
            builder: (context, state) {
              return PopupMenuButton<Color>(
                icon: Icon(
                  Icons.color_lens,
                  color: state.currentColor,
                ),
                onSelected: (color) => cubit.changeColor(color),
                itemBuilder: (context) => [
                  PopupMenuItem(value: Colors.black, child: Container(color: Colors.black, height: 20, width: 20)),
                  PopupMenuItem(value: Colors.red, child: Container(color: Colors.red, height: 20, width: 20)),
                  PopupMenuItem(value: Colors.blue, child: Container(color: Colors.blue, height: 20, width: 20)),
                  PopupMenuItem(value: Colors.green, child: Container(color: Colors.green, height: 20, width: 20)),
                ],
              );
            },
          ),
          BlocBuilder<DrawingCubit, DrawingState>(
            buildWhen: (previous, current) => previous.currentWidth != current.currentWidth,
            builder: (context, state) {
              return PopupMenuButton<double>(
                icon: Icon(
                  Icons.line_weight,
                  color: Colors.white,
                ),
                onSelected: (width) => cubit.changeWidth(width),
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 1.0, child: Text('1px')),
                  const PopupMenuItem(value: 3.0, child: Text('3px')),
                  const PopupMenuItem(value: 5.0, child: Text('5px')),
                  const PopupMenuItem(value: 10.0, child: Text('10px')),
                ],
              );
            },
          ),
          BlocBuilder<DrawingCubit, DrawingState>(
            buildWhen: (previous, current) => previous.eraserWidth != current.eraserWidth,
            builder: (context, state) {
              if (state.currentTool == DrawingTool.eraser) {
                return PopupMenuButton<double>(
                  icon: Icon(
                    Icons.circle,
                    color: Colors.white,
                    size: state.eraserWidth,
                  ),
                  onSelected: (width) => cubit.changeEraserWidth(width),
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 10.0, child: Text('Pequena')),
                    const PopupMenuItem(value: 20.0, child: Text('Média')),
                    const PopupMenuItem(value: 40.0, child: Text('Grande')),
                  ],
                );
              } else {
                return const SizedBox.shrink();
              }
            },
          ),
        ],
      ),
      body: BlocBuilder<DrawingCubit,DrawingState>(
        builder: (context, state) {
          return Listener(
            onPointerDown: (details) {
              cubit.startDrawing(details.localPosition);
            },
            onPointerMove: (details) {
              cubit.updateDrawing(details.localPosition);
            },
            onPointerUp: (details) {
              cubit.endDrawing();
            },
            child: DrawingCanvas(
              strokes: state.strokes,
              currentStroke: state.currentStroke,
              currentTool: state.currentTool,
              eraserWidth: state.eraserWidth,
            ),
          );
        }
      ),
    );
  }
}