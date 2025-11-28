import 'package:equalatam/src/features/tracking/corporate_tracking/presentation/pages/bulk_upload_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/corporate_bloc.dart';
import '../bloc/corporate_event.dart';
import '../bloc/corporate_state.dart';
import '../widgets/bulk_list_widget.dart';
import '../../data/datasources/corporate_tracking_remote_ds.dart';
import '../../data/repositories/corporate_tracking_repository_impl.dart';

class CorporateHomePage extends StatefulWidget { const CorporateHomePage({super.key}); @override State<CorporateHomePage> createState() => _CorporateHomePageState(); }

class _CorporateHomePageState extends State<CorporateHomePage> {
  late final CorporateBloc _bloc;
  final _clientRefCtrl = TextEditingController(text:'CLIENT-1');
  @override void initState(){ super.initState(); final repo = CorporateTrackingRepositoryImpl(CorporateTrackingRemoteDataSource()); _bloc = CorporateBloc(repository: repo); _bloc.add(LoadClientRecords(_clientRefCtrl.text)); }
  @override void dispose(){ _clientRefCtrl.dispose(); _bloc.close(); super.dispose(); }

  @override Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: Scaffold(
        appBar: AppBar(title: const Text('Panel Corporativo - Tracking')),
        body: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
          Row(children:[
            Expanded(child: TextFormField(controller:_clientRefCtrl, decoration: const InputDecoration(labelText:'Client Ref'))),
            const SizedBox(width:12),
            ElevatedButton(onPressed: ()=> _bloc.add(LoadClientRecords(_clientRefCtrl.text)), child: const Text('Cargar')),
            const SizedBox(width:8),
            ElevatedButton(onPressed: ()=> Navigator.push(context, MaterialPageRoute(builder: (_) => BulkUploadPage(clientRef: _clientRefCtrl.text))), child: const Text('Subir CSV'))
          ]),
          const SizedBox(height:12),
          const Text('Registros', style: TextStyle(fontSize:18, fontWeight: FontWeight.bold)),
          const SizedBox(height:8),
          Expanded(child: BlocBuilder<CorporateBloc, CorporateState>(builder:(context,state){
            if (state.loading) return const Center(child:CircularProgressIndicator());
            if (state.error != null) return Center(child: Text('Error: ${state.error}'));
            return BulkListWidget(records: state.records);
          })),
        ])),
      ),
    );
  }
}
