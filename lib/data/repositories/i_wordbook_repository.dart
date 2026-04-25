import '../models/wordbook.dart';

abstract class IWordbookRepository {
  Future<List<Wordbook>> getWordbooks();
  Future<List<Wordbook>> getBuiltInWordbooks();
  Future<Wordbook?> getWordbookById(String id);
}
