package one;

import java.io.IOException;
import java.nio.file.*;
import java.nio.file.attribute.BasicFileAttributes;
import java.util.concurrent.atomic.AtomicInteger;

public class Task3 {
    public static void main(String[] args) {
        java.util.Scanner scanner = new java.util.Scanner(System.in);

        System.out.println("=== Задание 3: Копирование директории ===\n");

        System.out.print("Введите путь к исходной директории: ");
        String sourcePath = scanner.nextLine();

        System.out.print("Введите путь к новой директории: ");
        String targetPath = scanner.nextLine();

        Path sourceDir = Paths.get(sourcePath);
        Path targetDir = Paths.get(targetPath);

        // Проверяем существование исходной директории
        if (!Files.exists(sourceDir) || !Files.isDirectory(sourceDir)) {
            System.err.println("Ошибка: исходная директория не существует!");
            return;
        }

        // Статистика
        AtomicInteger filesCopied = new AtomicInteger(0);
        AtomicInteger dirsCreated = new AtomicInteger(0);
        AtomicInteger errors = new AtomicInteger(0);

        // Поток копирования
        Thread copyThread = new Thread(() -> {
            try {
                System.out.println("Поток копирования: начинаю копирование...");
                System.out.println("Из: " + sourceDir);
                System.out.println("В: " + targetDir);

                Files.walkFileTree(sourceDir, new SimpleFileVisitor<Path>() {
                    @Override
                    public FileVisitResult preVisitDirectory(Path dir, BasicFileAttributes attrs) {
                        try {
                            // Создаём соответствующую директорию в целевом пути
                            Path target = targetDir.resolve(sourceDir.relativize(dir));
                            Files.createDirectories(target);
                            dirsCreated.incrementAndGet();
                            System.out.println("Создана директория: " + target);
                        } catch (IOException e) {
                            System.err.println("Ошибка создания директории: " + e.getMessage());
                            errors.incrementAndGet();
                            return FileVisitResult.SKIP_SUBTREE;
                        }
                        return FileVisitResult.CONTINUE;
                    }

                    @Override
                    public FileVisitResult visitFile(Path file, BasicFileAttributes attrs) {
                        try {
                            // Копируем файл
                            Path target = targetDir.resolve(sourceDir.relativize(file));
                            Files.copy(file, target, StandardCopyOption.REPLACE_EXISTING);
                            filesCopied.incrementAndGet();
                            System.out.println("Скопирован файл: " + file.getFileName());
                        } catch (IOException e) {
                            System.err.println("Ошибка копирования файла " + file + ": " + e.getMessage());
                            errors.incrementAndGet();
                        }
                        return FileVisitResult.CONTINUE;
                    }

                    @Override
                    public FileVisitResult visitFileFailed(Path file, IOException exc) {
                        System.err.println("Ошибка доступа к файлу " + file + ": " + exc.getMessage());
                        errors.incrementAndGet();
                        return FileVisitResult.CONTINUE;
                    }
                });

                System.out.println("Поток копирования: копирование завершено!");

            } catch (IOException e) {
                System.err.println("Ошибка при обходе дерева: " + e.getMessage());
                errors.incrementAndGet();
            }
        });

        long startTime = System.currentTimeMillis();

        copyThread.start();

        try {
            copyThread.join(); // Ждём завершения потока
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }

        long endTime = System.currentTimeMillis();

        // Статистика в main
        System.out.println("\n=== СТАТИСТИКА В MAIN ===");
        System.out.println("Создано директорий: " + dirsCreated.get());
        System.out.println("Скопировано файлов: " + filesCopied.get());
        System.out.println("Ошибок: " + errors.get());
        System.out.println("Время выполнения: " + (endTime - startTime) + " мс");
        System.out.println("Целевая директория: " + targetDir.toAbsolutePath());
    }
}