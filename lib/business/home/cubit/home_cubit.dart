import 'package:frtodo/business/home/cubit/home_state.dart';
import 'package:bloc/bloc.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit() : super(const HomeState());

  void setTab(HomeTab tab) => emit(HomeState(tab: tab));
}
