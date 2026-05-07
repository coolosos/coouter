abstract class Codable<T> {
  const Codable();

  Codable decode(T remote);

  Codable<T> bodyFromMap(Map<String, dynamic> data);
}
