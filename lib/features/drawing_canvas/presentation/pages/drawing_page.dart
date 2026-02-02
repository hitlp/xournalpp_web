import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xournalpp_web/features/drawing_canvas/domain/entities/drawing_tool.dart';
import 'package:xournalpp_web/features/drawing_canvas/presentation/bloc/drawing_cubit.dart';
import 'package:xournalpp_web/features/drawing_canvas/presentation/bloc/drawing_state.dart';
import 'package:xournalpp_web/features/drawing_canvas/presentation/widgets/drawing_canvas.dart';

class DrawingPage extends StatelessWidget {
  const DrawingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DrawingCubit(),
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
          BlocBuilder<DrawingCubit, DrawingState>(
            buildWhen: (previous, current) => previous.currentTool != current.currentTool,
            builder: (context, state) {
              return IconButton(
                icon: Icon(Icons.edit, color: state.currentTool == DrawingTool.pen ? Colors.white : Colors.grey,),
                onPressed: () => cubit.changeTool(DrawingTool.pen)
                );
            } 
          ),
          BlocBuilder<DrawingCubit, DrawingState>(
            buildWhen: (previous, current) => previous.currentTool != current.currentTool,
            builder: (context, state) {
              return IconButton(
                icon: Icon(Icons.cleaning_services, color: state.currentTool == DrawingTool.eraser ? Colors.white : Colors.grey,),
                onPressed: () => cubit.changeTool(DrawingTool.eraser), 
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.color_lens),
            onPressed: () => cubit.changeColor(Colors.red), 
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () async {
              await cubit.saveFile();
            }
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
            ),
          );
        }
      ),
    );
  }
}