import 'package:equatable/equatable.dart';

abstract class CasesState extends Equatable {
  const CasesState();
  @override
  List<Object> get props => [];
}

class CasesInitial extends CasesState {}

class CasesLoading extends CasesState {}

class CasesLoaded extends CasesState {
  final List<Map<String, dynamic>> cases;
  const CasesLoaded(this.cases);
  @override
  List<Object> get props => [cases];
}

class CasesError extends CasesState {
  final String message;
  const CasesError(this.message);
  @override
  List<Object> get props => [message];
}
