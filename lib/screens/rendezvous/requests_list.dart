import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RequestsList extends StatefulWidget {
  final String email; // Pass the user's email

  const RequestsList({Key? key, required this.email}) : super(key: key);

  @override
  State<RequestsList> createState() => _RequestsListState();
}

class _RequestsListState extends State<RequestsList> {
  List<Map<String, dynamic>> _demandes = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchDemandes();
  }

  Future<void> _fetchDemandes() async {
    final url = Uri.parse(
      'http://localhost:3000/patients/demandes/${widget.email}',
    );
    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _demandes =
              data
                  .map(
                    (demande) => {
                      'id_rdv': demande['id_rdv'] ?? 0, // Default to 0 if null
                      'motif': demande['motif'] ?? 'Motif inconnu',
                      'date':
                          DateTime.tryParse(demande['date_depot'] ?? '') ??
                          DateTime.now(), // Default to current date if parsing fails
                      'status': 'En attente', // Default status for demandes
                    },
                  )
                  .toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Erreur lors de la récupération des demandes.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Impossible de se connecter au serveur.';
        _isLoading = false;
      });
    }
  }

  Future<void> _cancelDemande(BuildContext context, int idRdv) async {
    final url = Uri.parse(
      'https://educare-backend-l6ue.onrender.com/patients/annulerdv/$idRdv',
    );
    try {
      final response = await http.put(url);

      if (response.statusCode == 200) {
        setState(() {
          _demandes.removeWhere((demande) => demande['id_rdv'] == idRdv);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Demande annulée avec succès')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de l\'annulation')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible de se connecter au serveur')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(child: Text(_errorMessage!));
    }

    if (_demandes.isEmpty) {
      return const Center(
        child: Text(
          'Pas de demandes',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _demandes.length,
      itemBuilder: (context, index) {
        final demande = _demandes[index];
        return _RequestCard(
          motif: demande['motif'],
          date: demande['date'],
          status: demande['status'],
          idRdv: demande['id_rdv'], // Pass the ID of the demande
          onCancel: () => _cancelDemande(context, demande['id_rdv']),
        );
      },
    );
  }
}

class _RequestCard extends StatelessWidget {
  final String motif;
  final DateTime date;
  final String status;
  final int idRdv;
  final VoidCallback onCancel;

  const _RequestCard({
    required this.motif,
    required this.date,
    required this.status,
    required this.idRdv,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              motif,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              'Demandé le ${_formatDate(date)}',
              style: const TextStyle(color: Color.fromRGBO(113, 128, 150, 1)),
            ),
            const SizedBox(height: 8),
            Text(
              'Statut : $status',
              style: const TextStyle(color: Color(0xFF718096)),
            ),
            const SizedBox(height: 16),
            if (status ==
                'En attente') // Show the button only if the status is "En attente"
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: onCancel,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Annuler',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
